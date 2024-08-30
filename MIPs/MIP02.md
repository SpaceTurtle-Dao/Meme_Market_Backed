**Model**

**Profile Object**
```lua
{
    name = string,
    image = string,
    text = string,
    createdAt = Number
}
```
**Endpoints**

**Profile** 
```lua
--updates and creates a Profile
ao.send({
    Target = ProcessId,
    Action = 'Profile',
    Name = "spaceturtle",
    Image = "arweave transaction"
})
```

**Get Profile**
```lua
ao.send({
    Target = ProcessId,
    Action = 'GetProfile',
    Profile = "ProcessId of profile owner"
})
--returns post object
```

**Fetch Profile**
```lua
ao.send({
    Target = ProcessId,
    Action = 'FetchProfiles',
    Page = 0
    Size = 100
})
--returns an Array of post object
```
**Fetch Profile Post**
```lua
ao.send({
    Target = ProcessId,
    Action = 'FetchProfileMemes',
    Page = 0
    Size = 100
})
--returns an Array of post object
```