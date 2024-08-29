**Model**

**ProfileRequest Object**

```lua
{
    name = string,
    image = string
}
```
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
    Data = profileRequest
})
```

**Get Profile**
```lua
ao.send({
    Target = ProcessId,
    Action = 'getProfile',
    owner = owner
})
--returns post object
```

**Fetch Profile**
```lua
ao.send({
    Target = ProcessId,
    Action = 'fetchProfiles',
    Page = 0
    Size = 100
})
--returns an Array of post object
```
**Fetch Profile Post**
```lua
ao.send({
    Target = ProcessId,
    Action = 'fetchProfilePosts',
    Page = 0
    Size = 100
})
--returns an Array of post object
```