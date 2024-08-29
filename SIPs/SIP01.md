
**Models**

**MemeRequest Object**
```lua
{
    Kind = Number,
    Tags = [string], --array of processIds
    Content = string, --<arbitrary stringified JSON object or string depending on kind>
    AmountA = string,
    AmountB = string,
}
```

**Meme Object**
```lua
 {
    Pool = string,
    Creator = string,
    TokenA = string,
    TokenB = string,
    Denomination = Default_Denomination,
    Supply = Default_Supply,
    Holders = {},
    Kind = Number,
    Tags = [string],
    Content = string,
    Engagement = {},
    Analytics = {}
    Created_at = Number,
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

**Meme**
```lua
--creates a token, a pool and makes the creator the only liquidty provider using amount specified by the creator
ao.send({
    Target = ProcessId,
    Action = 'Meme',
    Data = MemeRequest
})
```
**Reply**
```lua
ao.send({
    Target = ProcessId,
    Action = 'Reply',
    Data = MemeRequest
    MemeId = 0
})
```

**Pump**
```lua
ao.send({
    Target = ProcessId,
    Action = 'Pump',
    MemeId = 0,
    Amount = 100
})
```

**Like**
```lua
ao.send({
    Target = ProcessId,
    Action = 'Dump',
    MemeId = 0,
    Amount = 100
})
```

**Get Meme**
```lua
ao.send({
    Target = ProcessId,
    Action = 'GetMeme',
    MemeId = 0
})
--returns Meme object
```

**Fetch Meme**
```lua
ao.send({
    Target = ProcessId,
    Action = 'FetchMemes',
    Page = 0
    Size = 100
})
--returns an Array of Meme object
```

**Fetch Feed**
```lua
ao.send({
    Target = ProcessId,
    Action = 'FetchFeed',
    Page = 0
    Size = 100
})
--returns an Array of Meme object orded in decending order by marketcap
```

**Fetch Likes**
```lua
ao.send({
    Target = ProcessId,
    Action = 'FetchLikes',
    Page = 0
    Size = 100
})
--returns an Array of processIds
```

**Fetch Replies**
```lua
ao.send({
    Target = ProcessId,
    Action = 'FetchReplies',
    Replies = [string]
})
--returns an Array of Meme Objects
```

