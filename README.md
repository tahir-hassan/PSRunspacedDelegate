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

### Installation from PowerShell Gallery

To install it from the PowerShell Gallery, run the following command:

```powershell
Install-Module PSRunspacedDelegate -Scope CurrentUser
```

## Function Provided

Use the function `New-RunspacedDelegate` to create a delegate that has access to the PowerShell environment. The delegate that `New-RunspacedDelegate` produces will be the same as the input delegate type.  Therefore, if you pass a `Func<int, int>`, you will get a `Func<int, int>` as output.  If you pass `Action<string, List<string>>`, you will get the same type, `Action<string, List<string>>`, as its output. Simply put, if you pass an argument of type `T` (as long as `T` is a delegate type), you will get an object of type `T` as output.

## Example of Use

In the example below, I pass a `System.Action` delegate to `New-RunspacedDelegate` which produces a new `System.Action` delegate which can access the current PowerShell runspace. Your delegate can access all `Global` and `Script` scoped variables. You cannot access your local variables, but below I have described a workaround. 

```powershell
# Create the Jira REST client
$client = [Atlassian.Jira.Jira]::CreateRestClient($jiraUrl, $Username, $Password);

$workLog = New-Object Atlassian.Jira.Worklog $Time,([DateTime]::Now),"log time"

# $task is a Task<Worklog> object
$task = $client.Issues.AddWorklogAsync($Issue, $workLog, [Atlassian.Jira.WorklogStrategy]::AutoAdjustRemainingEstimate, $null, (New-Object System.Threading.CancellationToken $false))

# $awaiter is a TaskAwaiter<Worklog>
$awaiter = $task.GetAwaiter();

# $action is a System.Action
$action = New-RunspacedDelegate ([System.Action]{ 
    # You can put PowerShell code in here
});

# $action can be safely be passed to awaiter's OnCompleted method
$awaiter.OnCompleted($action);
```

## Access to local variables

The best way to access local variables, in my opinion, is to store them in a queue object (`System.Collections.Generic.Queue<object>`). You can queue a hashtable containing the variables, then dequeue it in the delegate. The queue must at `Script` or `Global` scope.

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

# queue it:
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
