//
//  main.swift
//  AOC1919
//
//  Created by Heiko Goes on 08.01.20.
//  Copyright © 2020 Heiko Goes. All rights reserved.
//

import Foundation

enum Opcode: Int {
    case Add = 1
    case Multiply = 2
    case Halt = 99
    case Input = 3
    case Output = 4
    case JumpIfTrue = 5
    case JumpIfFalse = 6
    case LessThan = 7
    case Equals = 8
    case AdjustRelativeBase = 9
}

extension String {
    subscript (bounds: CountableClosedRange<Int>) -> String {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return String(self[start...end])
    }

    subscript (bounds: CountableRange<Int>) -> String {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return String(self[start..<end])
    }
}

struct ParameterModes {
    let digits: String
    private var parameterPointer: Int
    
    init(digits: String) {
        self.digits = digits
        parameterPointer = digits.count - 1
    }
    
    mutating func getNext() -> ParameterMode {
        let digit = parameterPointer >= 0 ? digits[parameterPointer...parameterPointer] : "0"
        parameterPointer -= 1
        
        return ParameterMode(rawValue: Int(digit)!)!
    }
}

enum ParameterMode: Int {
    case Position = 0
    case Immediate = 1
    case Relative = 2
}

struct Program {
    private(set) var memory: [Int]
    private var instructionPointer = 0
    private var relativeBase = 0
    
    public mutating func getNextParameter(parameterMode: ParameterMode) -> Int {
        var parameter: Int
        switch parameterMode {
            case .Position:
                parameter = memory[memory[instructionPointer]]
            case .Immediate:
                parameter = memory[instructionPointer]
            case .Relative:
                parameter = memory[memory[instructionPointer] + relativeBase]
        }
        
        instructionPointer += 1
        return parameter
    }
    
    public mutating func run(input: [Int]) -> [Int] {
        var inputIterator = input.makeIterator()
        var result = [Int]()
        
        repeat {
            var startString = String(memory[instructionPointer])
            if startString.count == 1 {
                startString = "0" + startString
            }
            
            instructionPointer += 1
            
            let opcode = Opcode(rawValue: Int(startString[startString.count - 2...startString.count - 1])!)!
            if opcode == .Halt {
                return result
            }
            
            var parameterModes = startString.count >= 3 ? ParameterModes(digits: startString[0...startString.count - 3]) : ParameterModes(digits: "")
            
            switch opcode {
                case .Add:
                    let parameter1 = getNextParameter(parameterMode: parameterModes.getNext())
                    let parameter2 = getNextParameter(parameterMode: parameterModes.getNext())
                    let parameter3 = getNextParameter(parameterMode: .Immediate)
                    
                    let parameterMode = parameterModes.getNext()
                    if parameterMode == .Relative {
                        memory[parameter3 + relativeBase] = parameter1 + parameter2
                    } else {
                        memory[parameter3] = parameter1 + parameter2
                    }
                case .Multiply:
                    let parameter1 = getNextParameter(parameterMode: parameterModes.getNext())
                    let parameter2 = getNextParameter(parameterMode: parameterModes.getNext())
                    let parameter3 = getNextParameter(parameterMode: .Immediate)
                    
                    let parameterMode = parameterModes.getNext()
                    if parameterMode == .Relative {
                        memory[parameter3 + relativeBase] = parameter1 * parameter2
                    } else {
                        memory[parameter3] = parameter1 * parameter2
                    }
                case .Halt: ()
                case .Input:
                    let parameter = getNextParameter(parameterMode: .Immediate)
                    let parameterMode = parameterModes.getNext()
                    if parameterMode == .Relative {
                        memory[parameter + relativeBase] = inputIterator.next()!
                    } else {
                        memory[parameter] = inputIterator.next()!
                    }
                case .Output:
                    let parameter1 = getNextParameter(parameterMode: parameterModes.getNext())
                    result.append(parameter1)
                case .JumpIfTrue:
                    let parameter1 = getNextParameter(parameterMode: parameterModes.getNext())
                    if parameter1 != 0 {
                        let parameter2 = getNextParameter(parameterMode: parameterModes.getNext())
                        instructionPointer = parameter2
                    } else {
                        instructionPointer += 1
                    }
                case .JumpIfFalse:
                    let parameter1 = getNextParameter(parameterMode: parameterModes.getNext())
                    if parameter1 == 0 {
                        let parameter2 = getNextParameter(parameterMode: parameterModes.getNext())
                        instructionPointer = parameter2
                    } else {
                        instructionPointer += 1
                    }
                case .LessThan:
                    let parameter1 = getNextParameter(parameterMode: parameterModes.getNext())
                    let parameter2 = getNextParameter(parameterMode: parameterModes.getNext())
                    let parameter3 = getNextParameter(parameterMode: .Immediate)
                    
                    let parameterMode = parameterModes.getNext()
                    let value = parameter1 < parameter2 ? 1 : 0
                    if parameterMode == .Relative {
                        memory[parameter3 + relativeBase] = value
                    } else {
                        memory[parameter3] = value
                    }
                case .Equals:
                   let parameter1 = getNextParameter(parameterMode: parameterModes.getNext())
                   let parameter2 = getNextParameter(parameterMode: parameterModes.getNext())
                   let parameter3 = getNextParameter(parameterMode: .Immediate)
                   
                   let parameterMode = parameterModes.getNext()
                   let value = parameter1 == parameter2 ? 1 : 0
                   if parameterMode == .Relative {
                        memory[parameter3 + relativeBase] = value
                   } else {
                        memory[parameter3] = value
                    }
                case .AdjustRelativeBase:
                   let parameter = getNextParameter(parameterMode: parameterModes.getNext())
                   relativeBase += parameter
            }
        } while true
    }
    
    init(memory: String) {
        self.memory = memory
            .split(separator: ",")
            .map{ Int($0)! }
    }
}

let memoryString = """
109,424,203,1,21102,11,1,0,1106,0,282,21101,0,18,0,1106,0,259,1201,1,0,221,203,1,21102,1,31,0,1106,0,282,21101,0,38,0,1106,0,259,20102,1,23,2,21202,1,1,3,21101,1,0,1,21101,0,57,0,1105,1,303,2101,0,1,222,20101,0,221,3,21001,221,0,2,21102,1,259,1,21101,0,80,0,1105,1,225,21101,185,0,2,21102,91,1,0,1106,0,303,1202,1,1,223,21001,222,0,4,21102,259,1,3,21101,225,0,2,21102,1,225,1,21101,0,118,0,1106,0,225,20102,1,222,3,21102,1,131,2,21101,133,0,0,1106,0,303,21202,1,-1,1,22001,223,1,1,21101,148,0,0,1105,1,259,2101,0,1,223,21002,221,1,4,21002,222,1,3,21101,0,16,2,1001,132,-2,224,1002,224,2,224,1001,224,3,224,1002,132,-1,132,1,224,132,224,21001,224,1,1,21101,0,195,0,106,0,109,20207,1,223,2,20101,0,23,1,21102,1,-1,3,21101,0,214,0,1105,1,303,22101,1,1,1,204,1,99,0,0,0,0,109,5,1201,-4,0,249,22101,0,-3,1,22101,0,-2,2,21201,-1,0,3,21101,0,250,0,1106,0,225,21201,1,0,-4,109,-5,2106,0,0,109,3,22107,0,-2,-1,21202,-1,2,-1,21201,-1,-1,-1,22202,-1,-2,-2,109,-3,2106,0,0,109,3,21207,-2,0,-1,1206,-1,294,104,0,99,22102,1,-2,-2,109,-3,2105,1,0,109,5,22207,-3,-4,-1,1206,-1,346,22201,-4,-3,-4,21202,-3,-1,-1,22201,-4,-1,2,21202,2,-1,-1,22201,-4,-1,1,21201,-2,0,3,21101,343,0,0,1106,0,303,1105,1,415,22207,-2,-3,-1,1206,-1,387,22201,-3,-2,-3,21202,-2,-1,-1,22201,-3,-1,3,21202,3,-1,-1,22201,-3,-1,2,22101,0,-4,1,21102,384,1,0,1106,0,303,1105,1,415,21202,-4,-1,-4,22201,-4,-3,-4,22202,-3,-2,-2,22202,-2,-4,-4,22202,-3,-2,-3,21202,-4,-1,-2,22201,-3,-2,1,21201,1,0,-4,109,-5,2106,0,0
"""
    + String(repeating: ",0", count: 10000)



struct Point: Hashable {
    let x: Int
    let y: Int
}

let affectedPoints = (0..<50).flatMap{ x in (0..<50).map{ y in (x:x, y:y) } }
    .reduce(into: [Point]()) { accu, current in
        var program = Program(memory: memoryString)
        if program.run(input: [current.x, current.y]) == [1] {
            accu.append(Point(x: current.x, y: current.y))
    }
}

print(affectedPoints.count)

let s = Set(affectedPoints)

for x in 0..<50 {
    for y in 0..<50 {
        if s.contains(Point(x: x, y: y)) {
            print("#", terminator:"")
        } else {
            print(".", terminator:"")
        }
    }
    print()
}
