# Get current DateTime and print it
$currentDateTime = Get-Date
Write-Host "Current Date and Time: $currentDateTime"

# Create two users with password as current DateTime
$user1 = "UserOne"
$user2 = "UserTwo"
$password = $currentDateTime.ToString()

# Create UserOne
net user $user1 $password /add

# Create UserTwo
net user $user2 $password /add

Write-Host "Users $user1 and $user2 have been created with password: $password"