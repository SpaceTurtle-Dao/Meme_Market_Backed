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
function SIP01(creator, created_at, tags, content,Kind)
    
end

function GetMIP01(id)
    if Memes[id] == nil then return end
    return Memes[id]
end
