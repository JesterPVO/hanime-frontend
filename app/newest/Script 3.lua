local consumeRemote = game:GetService("ReplicatedStorage")
    :WaitForChild("Systems")
    :WaitForChild("ActionsSystem")
    :WaitForChild("Network")
    :WaitForChild("Consume")

local WORKERS_PER_SLOT = 1 -- Kept low to prevent immediate network buffer overflow with 45 slots

local function startWorker(slot)
    while true do
        pcall(function()
            consumeRemote:InvokeServer(slot)
        end)
        task.wait() -- Minimal yield to keep client execution smooth
    end
end

-- Spawn loops for slots 1 through 45
for slot = 1, 45 do
    for worker = 1, WORKERS_PER_SLOT do
        task.spawn(startWorker, slot)
    end
end