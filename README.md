# PSRunspacedDelegate

PowerShell module for creating delegates for use with `*Async` methods.

## Function Provided

Use the function `New-RunspacedDelegate` to create a delegate that can reference objects within your PowerShell code.

## Example of Use

In the example below, I am creating a `System.Action` delegate and passing it to `New-RunspacedDelegate` which will then produce a new `System.Action` delegate which, when it runs, will set the runspace to the current PowerShell runspace.  This way you can access PowerShell variables in your delegate.

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

## Links

<a href="https://stackoverflow.com/questions/25851704/getting-result-of-net-object-asynchronous-method-in-powershell">StackOverflow.com Question</a>
