//
//  Utils.swift
//  ExNihilo
//
//  Created by Vayn on 2017/1/8.
//  Copyright © 2017年 Vayn. All rights reserved.
//

import Cocoa
import IOKit.ps

enum CapacityLevel: Int {
    case half = 50
    case empty = 20

    func color() -> NSColor {
        switch self {
        case .half:
            return NSColor(calibratedRed: 0.83, green: 0.36, blue: 0.00, alpha: 1)
        case .empty:
            return NSColor(calibratedRed: 0.81, green: 0.15, blue: 0.06, alpha: 1)
        }
    }
}

private enum PowerSourcesError: Error {
    case infoNotExist
    case listNotExist
    case descriptionNotExist
}

public struct BatteryInfo {
    var currentCapacity: Int = 0
    var maxCapacity: Int = 0
    var cycleCount: Int = 0
    var temperature: Double = 0.0
    var health: String = ""
    var timeRemaining: String = ""
}

public struct Utils {

    public static func batteryInfo() -> BatteryInfo {
        var batteryInfo: BatteryInfo = BatteryInfo()

        do {
            guard let blob = IOPSCopyPowerSourcesInfo()?.takeRetainedValue() else {
                throw PowerSourcesError.infoNotExist
            }

            guard let sources: NSArray = IOPSCopyPowerSourcesList(blob)?.takeRetainedValue() else {
                throw PowerSourcesError.listNotExist
            }

            for ps in sources {
                guard let info: NSDictionary = IOPSGetPowerSourceDescription(blob, ps as AnyObject?)? .takeUnretainedValue()
                    else { throw PowerSourcesError.descriptionNotExist }

                if let capacity = info[kIOPSCurrentCapacityKey] as? Int {
                    batteryInfo.currentCapacity = capacity
                }

                if let health = info[kIOPSBatteryHealthKey] as? String {
                    batteryInfo.health = health
                }

                if let max = info[kIOPSMaxCapacityKey] as? Int {
                    batteryInfo.maxCapacity = max
                }

                #if DEBUG
                    if let name = info[kIOPSNameKey] as? String {
                        print("\(name)")
                    }
                #endif

                break
            }

            let timeRemaining: CFTimeInterval = IOPSGetTimeRemainingEstimate()

            if timeRemaining == kIOPSTimeRemainingUnlimited {
                batteryInfo.timeRemaining = "Plugged"
            } else if timeRemaining == kIOPSTimeRemainingUnknown {
                batteryInfo.timeRemaining = "Recently Unplugged"
            } else {
                let totalSeconds = lrint(timeRemaining) // Round to nearest integer
                let hours = totalSeconds / 3600
                let minutes = (totalSeconds % 3600) / 60
                let seconds = totalSeconds % 60
                batteryInfo.timeRemaining = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
            }

            let entry: io_registry_entry_t = IOServiceGetMatchingService(kIOMasterPortDefault,
                                                                         IOServiceMatching("AppleSmartBattery"))
            /*
             var buffer = [Int8](repeating: 0, count: 512)
             IORegistryEntryGetPath(entry, kIOServicePlane, &buffer)
             let ioPath: String = String.init(cString: buffer)
             let entry: io_registry_entry_t = IORegistryEntryFromPath(kIOMasterPortDefault, ioPath)
             */
            var props: Unmanaged<CFMutableDictionary>?
            if IORegistryEntryCreateCFProperties(entry, &props, kCFAllocatorDefault, 0) == KERN_SUCCESS {
                if let props = props {
                    let dict = props.takeRetainedValue() as NSDictionary
                    batteryInfo.cycleCount = dict["CycleCount"] as! Int
                    batteryInfo.temperature = (dict["Temperature"] as! Double) / 100.0
                }
            }

            return batteryInfo
        } catch {
            fatalError()
        }
    }

    public static func uptime() -> (days: Int, hrs: Int, mins: Int, secs: Int) {
        var currentTime = time_t()
        var bootTime = timeval()
        var mib = [CTL_KERN, KERN_BOOTTIME]

        // NOTE: Use strideof(), NOT sizeof() to account for data structure
        // alignment (padding)
        // http://stackoverflow.com/a/27640066
        // https://devforums.apple.com/message/1086617#1086617
        var size = MemoryLayout<timeval>.stride

        let result = sysctl(&mib, u_int(mib.count), &bootTime, &size, nil, 0)

        if result != 0 {
            #if DEBUG
                print("ERROR - \(#file):\(#function) - errno = "
                    + "\(result)")
            #endif

            return (0, 0, 0, 0)
        }

        time(&currentTime)

        var uptime = currentTime - bootTime.tv_sec

        let days = uptime / 86400   // Number of seconds in a day
        uptime %= 86400

        let hrs = uptime / 3600     // Number of seconds in an hour
        uptime %= 3600

        let mins = uptime / 60
        let secs = uptime % 60

        return (days, hrs, mins, secs)
    }

    // MARK: - GPU related
    public static func getGPUNames() -> Array<String> {
        let devices = IOServiceMatching("IOPCIDevice")
        var entryIterator: io_iterator_t = 0
        var gpus = [String]()

        if IOServiceGetMatchingServices(kIOMasterPortDefault, devices, &entryIterator) == kIOReturnSuccess {
            while case let device: io_registry_entry_t = IOIteratorNext(entryIterator), device != 0 {
                var serviceDictionary: Unmanaged<CFMutableDictionary>?

                if IORegistryEntryCreateCFProperties(device, &serviceDictionary, kCFAllocatorDefault, 0) != kIOReturnSuccess {
                    // Couldn't get the properties for this service, so clean up and
                    // continue.
                    IOObjectRelease(device)
                    continue
                }

                if let serviceDictionary = serviceDictionary {
                    let dict = serviceDictionary.takeRetainedValue() as NSDictionary

                    if let ioName = dict["IOName"] {
                        // If we have an IOName, and its value is "display", then we've
                        // got a "model" key, whose value is a CFDataRef that we can
                        // convert into a string.
                        if CFGetTypeID(ioName as CFTypeRef) == CFStringGetTypeID() &&
                            CFStringCompare((ioName as! CFString), "display" as CFString, .compareCaseInsensitive) == .compareEqualTo {
                            let model = dict["model"]
                            if let gpuName = String(data: model as! Data, encoding: String.Encoding.ascii) {
                                gpus.append(gpuName)
                            }
                        }
                    }
                }
            }
        }

        return gpus
    }

    fileprivate static func isUsingIntegratedGPU() -> Bool {
        let activeGraphicsCard: UInt64 = 7 // get: returns active graphics card
        var kernResult: kern_return_t = 0

        var connect: io_service_t = IO_OBJECT_NULL
        var service: io_service_t = IO_OBJECT_NULL
        var iterator: io_iterator_t = IO_OBJECT_NULL

        // Look up the objects we wish to open.
        // This creates an io_iterator_t of all instances of our driver that exist in the I/O Registry.
        kernResult = IOServiceGetMatchingServices(kIOMasterPortDefault, IOServiceMatching("AppleGraphicsControl"), &iterator);
        if (kernResult != KERN_SUCCESS) {
            print(String(format: "IOServiceGetMatchingServices returned 0x%08x.", kernResult))
        }

        service = IOIteratorNext(iterator) // actually there is only 1 such service
        IOObjectRelease(iterator)

        if (service == IO_OBJECT_NULL) {
            print("No matching drivers found.")
            return true
        }

        kernResult = IOServiceOpen(service, mach_task_self_, 0, &connect);
        if (kernResult != KERN_SUCCESS) {
            print(String(format: "IOServiceOpen returned 0x%08x.", kernResult))
        }

        let scalar: [UInt64] = [ 1 /* Always 1 (kMuxControl?) */, activeGraphicsCard /* Feature Info */ ]
        var output: UInt64 = 0
        var outputCount: UInt32 = 1

        kernResult = IOConnectCallScalarMethod(connect,         // an io_connect_t returned from IOServiceOpen().
                                               2,               // selector of the function to be called via the user client.
                                               scalar,          // array of scalar (64-bit) input values.
                                               2,               // the number of scalar input values.
                                               &output,         // array of scalar (64-bit) output values.
                                               &outputCount)    // pointer to the number of scalar output values.

        if (kernResult == KERN_SUCCESS) {
            print(String(format: "getState was successful (count=%d, value=0x%08llx).", outputCount, output))
        } else {
            print(String(format: "getState returned 0x%08x.", kernResult))
        }

        return output != 0
    }

}
