
**Models**

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
--creates a token, a pool and makes the creator the first buyer using amount specified by the creator
{
  "process": "WPyLgOqELOyN_BoTNdeEMZp5sz3RxDL19IGcs3A9IPc", --use wAr token in prod
  "data": "",
  "tags": [
    {
      "name": "Action",
      "value": "Transfer"
    },
    {
      "name": "Quantity",
      "value": "1000000000000"
    },
    {
      "name": "Recipient",
      "value": "Pool process"
    },
    {
      "name": "'X-Kind'",
      "value": "1"
    },
    {
      "name": "X-Tags",
      "value": "[]"
    },
    {
      "name": "X-Content",
      "value": "Whats up"
    },
    {
      "name": "X-Amount",
      "value": "1000000000000000000"
    }
  ]
}
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

**Pump/Dump**
```lua
--buys or sells depending on what token you are pointing to
{
  "process": "WPyLgOqELOyN_BoTNdeEMZp5sz3RxDL19IGcs3A9IPc", --either wAr token or meme atomic asset aka post
  "data": "",
  "tags": [
    {
      "name": "Action",
      "value": "Transfer"
    },
    {
      "name": "Recipient",
      "value": "CprNpySUQRkLGdC97KZUG2MyjqbZm_z1mRCm1ahEhc8"
    },
    {
      "name": "Quantity",
      "value": "10000000000"
    },
    {
      "name": "X-Swap",
      "value": ""
    },
    {
      "name": "X-Slippage",
      "value": "0"
    }
  ]
}
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
{
  "process": "AagnqYQkln2T9_s1YE5duAIpvwnF9WfGqSv-ru5b8Mk",
  "data": "",
  "tags": [
    {
      "name": "Action",
      "value": "FetchMemes"
    },
    {
      "name": "Page",
      "value": "1"
    },
    {
      "name": "Size",
      "value": "100"
    }
  ]
}
--returns an Array of Meme object
```

**Fetch Profile Meme**
```lua
{
  "process": "AagnqYQkln2T9_s1YE5duAIpvwnF9WfGqSv-ru5b8Mk",
  "data": "",
  "tags": [
    {
      "name": "Action",
      "value": "FetchProfileMemes"
    },
    {
      "name": "Page",
      "value": "1"
    },
    {
      "name": "Size",
      "value": "100"
    }
  ]
}
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

