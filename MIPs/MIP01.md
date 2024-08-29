
**Models**

**PostRequest Object**
```lua
{
    Kind = Number,
    Tags = [string], --array of processIds
    Content = string, --<arbitrary stringified JSON object or string depending on kind>
    AmountA = string,
    AmountB = string,
}
```

**Post Object**
```lua
 {
    Id = string,
    ProcessId = string,
    Creator = string,
    Created_at = Number,
    Kind = Number,
    Tags = [string],
    Content = string,
    Engagement = {},
    Analytics = {}
}
```
**Engagement Object**
```lua
{
    Pumps = [string],
    Dumps = [string],
    Replies = [string],
    
}
```
**Analytics Object**
```lua
{
    liquidty = string,
    volume = string,
    hourVolume = Volume,
    dayVolume = Volume,
    weekVolume = Volume,
    montlyVolume = Volume,
    marketCap = string,
    price = string,
};
```
***Volume Object**
```lua
{
    now = string,
    past = string
};
```
**Endpoints**

**Post**
```lua
--creates a token, a pool and makes the creator the only liquidty provider using amount specified by the creator
ao.send({
    Target = ProcessId,
    Action = 'Post',
    Data = postRequest
})
```
**Reply**
```lua
ao.send({
    Target = ProcessId,
    Action = 'Reply',
    Data = postRequest
    PostId = 0
})
```

**Pump**
```lua
ao.send({
    Target = ProcessId,
    Action = 'Pump',
    PostId = 0,
    Amount = 100
})
```

**Like**
```lua
ao.send({
    Target = ProcessId,
    Action = 'Dump',
    PostId = 0,
    Amount = 100
})
```

**Get Post**
```lua
ao.send({
    Target = ProcessId,
    Action = 'getPost',
    postId = 0
})
--returns post object
```

**Fetch Post**
```lua
ao.send({
    Target = ProcessId,
    Action = 'fetchPost',
    Page = 0
    Size = 100
})
--returns an Array of post object
```

**Fetch Feed**
```lua
ao.send({
    Target = ProcessId,
    Action = 'fetchFeed',
    Page = 0
    Size = 100
})
--returns an Array of post object orded in decending order by marketcap
```

**Fetch Likes**
```lua
ao.send({
    Target = ProcessId,
    Action = 'fetchLikes',
    Page = 0
    Size = 100
})
--returns an Array of processIds
```

**Fetch Replies**
```lua
ao.send({
    Target = ProcessId,
    Action = 'fetchReplies',
    Replies = [string]
})
--returns an Array of Post Objects
```

