local CyTest = {}
CyTest.__index = CyTest

CyTest.showFailureOnly = false

function CyTest.assert(condition, message)
    CyTest.print(condition, message)
    return condition
end

function CyTest.assertEqual(evalBlock, expected, message)
    local actual = evalBlock()
    if actual == expected then
        CyTest.print(true, message)
        return true
    else
        message = message..', Expected: '..expected..' Got: '..actual
        CyTest.print(false, message)
        return false
    end
end

function CyTest.print(success, message)
    if message then
        if success then
            if not CyTest.showFailureOnly then
                print("Test succeeded: "..message)
            end
        else
            print("Test failed: "..message)
        end
    end
end



return CyTest