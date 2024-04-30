$s1 = Get-ProjectsInMachine -sARTServerUri $sARTServerUri
$vision = $s1.vision.name
$blueprint = $s1._project._bluePrint.name
$task1 = $s1._project.pending_tasks[0].task.name