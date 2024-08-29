--Post
--MIP01
--[[
{
  "id": string,
  "processId": string,
  "created_at": string,
  "creator":string,
  "tags": [strings of processIds],
  "content": <arbitrary stringified JSON object>,
}
]]--
function MIP01(processId, creator, created_at, tags, content,Kind)
    local currentId = MIP_ID;
    MIP_ID = MIP_ID + 1;

    local mip = {
        Id = string,
        ProcessId = processId,
        Creator = creator,
        Created_at = created_at,
        Kind = Kind,
        Tags = tags,
        Content = content
    }
    Memes[tostring(currentId)] = mip
end

function FetchMIP01(pageNumber,pageSize)
    local startIndex = (pageNumber - 1) * pageSize + 1
    local endIndex = startIndex + pageSize - 1
    local paginatedResult = {}

    for i = startIndex, endIndex do
        if Memes[i] == nil then
            break
        end
        table.insert(paginatedResult, Memes[i])
    end

    return paginatedResult
end

function GetMIP01(id)
    if Memes[id] == nil then return end
    return Memes[id]
end
