import Foundation

final class RemoteCapacity: Connected {
    var outputprocess: OutputfromProcess?
    var config: Configuration?
    var command: OtherProcessCmdCombineClosure?

    func getremotecapacity() {
        if let config = self.config {
            guard SharedReference.shared.process == nil else { return }
            outputprocess = OutputfromProcess()
            // let config = Configuration(dictionary: dict)
            guard connected(config: config) == true else { return }
            let duargs = DuArgumentsSsh(config: self.config!)
            guard duargs.getArguments() != nil || duargs.getCommand() != nil else { return }

            command = OtherProcessCmdCombineClosure(command: duargs.getCommand(),
                                                    arguments: duargs.getArguments(),
                                                    processtermination: processtermination,
                                                    filehandler: filehandler)
            command?.executeProcess(outputprocess: outputprocess)
        }
    }

    init(config: Configuration) {
        self.config = config
    }
}

extension RemoteCapacity {
    func processtermination() {
        guard SharedReference.shared.process != nil else { return }
        // let numbers = RemoteNumbers(outputprocess: self.outputprocess)
        command = nil
    }

    func filehandler() {
        //
    }
}
