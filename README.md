# PSRunspacedDelegate

PowerShell module for creating delegates for use with `*Async` methods.

## Installation

### Installation from GitHub

Just clone this directory into a Module directory should be enough:

```powershell
# go to the WindowsPowerShell directory:
cd (Split-Path $PROFILE);

# make the Modules directory if it does not exist:
if (-not (Test-Path Modules)) {
    mkdir Modules | Out-Null;
}

# cd to the Modules directory
cd Modules;

# clone the repository
git clone https://github.com/tahir-hassan/PSRunspacedDelegate.git --depth 1;
```

## Function Provided

Use the function `New-RunspacedDelegate` to create a delegate that can reference objects within your PowerShell code.

## Example of Use

In the example below, I am creating a `System.Action` delegate and passing it to `New-RunspacedDelegate` which will then produce a new `System.Action` delegate which, when it runs, will set the runspace to the current PowerShell runspace.  This way you can access PowerShell `Global` and `Script` variables in your delegate. (You cannot access your local variables without promoting them to at least `Script` scope.)

```powershell
# Create the Jira REST client
$client = [Atlassian.Jira.Jira]::CreateRestClient($jiraUrl, $Username, $Password);

$workLog = New-Object Atlassian.Jira.Worklog $Time,([DateTime]::Now),"log time"

# $task is a Task<Worklog> object
$task = $client.Issues.AddWorklogAsync($Issue, $workLog, [Atlassian.Jira.WorklogStrategy]::AutoAdjustRemainingEstimate, $null, (New-Object System.Threading.CancellationToken $false))

# $awaiter is a TaskAwaiter<Worklog>
$awaiter = $task.GetAwaiter();

$action = New-RunspacedDelegate ([System.Action]{ 
    # You can put PowerShell code in here
});

$awaiter.OnCompleted($action);

```

## Access to local variables

The best way to access local variables, in my opinion, is to store them in a queue object (`System.Collections.Generic.Queue<object>`). You can queue a hashtable containing the variables, then dequeue it in the delegate. 

### Script scoped Queue

Declare a queue with `Script` scope in your module file:

```powershell
$Script:TaskQueue =  [System.Collections.Generic.Queue[object]]::new();
```

### Enqueue an object

Now enqueue a hashtable of the variables you want to access in the delegate:

```powershell
# local variables we want to access in the delegate:
$name = "Tahir";     # name
$surname = "Hassan"; # surname
$score = 83;

# create a hashtable of these local variables:
$taskObj = @{
    Name = $name;
    Surname = $surname;
    Store = $score;
};

# queue it up:
$Script:TaskQueue.Enqueue($taskObj);
```

### Dequeuing Within Delegate

You can now dequeue the element and access all the variables that were stored in there:

```powershell
$action = New-RunspacedDelegate ([System.Action]{ 
    # dequeue the object:
    $info = $Script:TaskQueue.Dequeue();

    # now use the variables in the hashtable:
    "Name: $( $info.Name ), Surname: $( $info.Surname ), Score: $( $info.Score )" | Out-File C:\Temp\information.txt -Append
});
```

## Links

<a href="https://stackoverflow.com/questions/25851704/getting-result-of-net-object-asynchronous-method-in-powershell">StackOverflow.com - Question on using Asynchronous methods in PowerShell</a>
