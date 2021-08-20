//
//  ComboboxRsyncParameters.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 11/10/2019.
//  Copyright © 2019 Thomas Evensen. All rights reserved.
//

import Foundation

struct Parameter: Identifiable {
    var id = UUID()
    var parameter: String?

    init(_ param: String) {
        parameter = param
    }
}

struct SetRsyncParameters {
    private var parameters = [String]()
    // private var config: Configuration?
    private var parametersset = [Parameter]()

    func getparameters() -> [Parameter] {
        if parametersset.count == 0 {
            return [Parameter("no parameters")]
        } else {
            return parametersset
        }
    }

    // Returns Int value of argument
    func indexrsyncargument(_ argument: String) -> Int {
        return RsyncArguments().arguments.firstIndex(where: { $0.0 == argument }) ?? -1
    }

    // Split an Rsync argument into argument and value
    private func split(_ str: String) -> [String] {
        let argument: String?
        let value: String?
        var split = str.components(separatedBy: "=")
        argument = String(split[0])
        if split.count > 1 {
            if split.count > 2 {
                split.remove(at: 0)
                value = split.joined(separator: "=")
            } else {
                value = String(split[1])
            }
        } else {
            value = argument
        }
        return [argument ?? "", value ?? ""]
    }

    // Function returns index and value of rsync argument to set the corrospending
    // value in combobox when rsync parameters are presented and stored in configuration
    func indexandvaluersyncparameter_int_string(_ parameter: String?) -> (Int, String) {
        guard parameter != nil else { return (0, "") }
        let splitstr: [String] = split(parameter ?? "")
        guard splitstr.count > 1 else { return (0, "") }
        let argument = splitstr[0]
        let value = splitstr[1]
        var returnvalue: String?
        var returnindex: Int?
        if argument != value, indexrsyncargument(argument) >= 0 {
            returnvalue = value
            returnindex = indexrsyncargument(argument)
        } else {
            if indexrsyncargument(splitstr[0]) >= 0 {
                returnvalue = "\"" + argument + "\" " + "no arguments"
            } else {
                if argument == value {
                    returnvalue = value
                } else {
                    returnvalue = argument + "=" + value
                }
            }
            if argument != value, indexrsyncargument(argument) >= 0 {
                returnindex = indexrsyncargument(argument)
            } else {
                if indexrsyncargument(splitstr[0]) >= 0 {
                    returnindex = indexrsyncargument(argument)
                } else {
                    returnindex = 0
                }
            }
        }
        return (returnindex ?? 0, returnvalue ?? "")
    }

    // Function returns index and value of rsync argument to set the corrospending
    // value in combobox when rsync parameters are presented and stored in configuration
    func indexandvaluersyncparameter(_ parameter: String?) -> String {
        guard parameter != nil else { return "" }
        let splitstr: [String] = split(parameter ?? "")
        guard splitstr.count > 1 else { return "" }
        let argument = splitstr[0]
        let value = splitstr[1]
        guard argument.isEmpty == false || value.isEmpty == false else { return "" }
        var returnvalue: String?
        var returnindex = -1
        if argument != value, indexrsyncargument(argument) >= 0 {
            returnvalue = value
            returnindex = indexrsyncargument(argument)
        } else {
            if indexrsyncargument(splitstr[0]) >= 0 {
                returnvalue = argument
            } else {
                if argument == value {
                    returnvalue = value
                } else {
                    returnvalue = argument + "=" + value
                }
            }
            if argument != value, indexrsyncargument(argument) >= 0 {
                returnindex = indexrsyncargument(argument)
            } else {
                if indexrsyncargument(splitstr[0]) >= 0 {
                    returnindex = indexrsyncargument(argument)
                } else {
                    returnindex = 0
                }
            }
        }
        guard returnindex > -1, returnindex < parameters.count else { return "" }
        if parameters[returnindex] == (returnvalue ?? "") {
            return parameters[returnindex]
        } else {
            return parameters[returnindex] + " = " + (returnvalue ?? "")
        }
    }

    // Function returns value of rsync a touple to set the corrosponding
    // value in combobox and the corrosponding rsync value when rsync parameters are presented
    // - parameter rsyncparameternumber : which stored rsync parameter, integer 8 - 14
    // - returns : touple with index for combobox and corresponding rsync value
    private mutating func setparameter(_ config: Configuration?) {
        if let config = config {
            let param8 = indexandvaluersyncparameter(config.parameter8)
            if param8.count > 0 {
                parametersset.append(Parameter(param8))
            }
            let param9 = indexandvaluersyncparameter(config.parameter9)
            if param9.count > 0 {
                parametersset.append(Parameter(param9))
            }
            let param10 = indexandvaluersyncparameter(config.parameter10)
            if param10.count > 0 {
                parametersset.append(Parameter(param10))
            }
            let param11 = indexandvaluersyncparameter(config.parameter11)
            if param11.count > 0 {
                parametersset.append(Parameter(param11))
            }
            let param12 = indexandvaluersyncparameter(config.parameter12)
            if param12.count > 0 {
                parametersset.append(Parameter(param12))
            }
            let param13 = indexandvaluersyncparameter(config.parameter13)
            if param13.count > 0 {
                parametersset.append(Parameter(param13))
            }
            let param14 = indexandvaluersyncparameter(config.parameter14)
            if param14.count > 0 {
                parametersset.append(Parameter(param14))
            }
        }
    }

    init(_ config: Configuration?) {
        for i in 0 ..< RsyncArguments().arguments.count {
            parameters.append(RsyncArguments().arguments[i].0)
        }
        setparameter(config)
    }
}
