#!/usr/bin/swift

/**
 * The library automatically tracks which SRG SSR applications are installed on a user device
 * and sends this information to comScore. For this mechanism to work properly, your application 
 * must declare all official SRG SSR application URL schemes as being supported in the Info.plist
 * file under LSApplicationQueriesSchemes.
 *
 * This script fetches all known schemes and writes out a plist for your convenience.
 *
 * @see https://developer.apple.com/library/content/documentation/General/Reference/InfoPlistKeyReference/Articles/LaunchServicesKeys.html
 */

import Foundation

/* The remote file contains a json with the schemes of all available SRG SSR apps. */
let configURL = URL(string: "https://pastebin.com/raw/RnZYEWCA")!

/* Name of plist file to store the schemes to. */
let fileName = "schemes.plist"

var waiting = true

print("☁️ Fetching configuration from server...")

let task = URLSession.shared.dataTask(with: configURL, completionHandler: { (data, response, error) in

    guard let data = data else {
        print("❌ Fetching configuration from remote server failed.")
        return
    }

    print("✔︎ Configuration download successful.")

    do {
        let json = try JSONSerialization.jsonObject(with: data, options: [.allowFragments])
        if let content = json as? NSArray {
            let schemes = content.compactMap({ (entry) -> String? in
                guard let entry = entry as? NSDictionary else {
                    return nil
                }
                if let scheme = entry.object(forKey: "ios") as? String {
                    return scheme.isEmpty ? nil : scheme
                }
                return nil
            })

            print("💾 Saving schemes to file \(fileName)")
            let schemesDictionary = ["LSApplicationQueriesSchemes": schemes]
            let written = (schemesDictionary as NSDictionary).write(toFile: fileName, atomically: true)
            if written {
                print("Done. Thanks. Bye. 🎉")
            } else {
                print("❌ Error while writing file to disk.")
            }
        }
        waiting = false
    } catch {
        print("❌ Parsing downloaded content failed. Doesn't seem to be JSON.")
    }
})
task.resume()

while waiting {}
