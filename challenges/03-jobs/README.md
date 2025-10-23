# Challenge: Jobs and CronJobs

## Task 1: Jobs

Refer to the [**Jobs**](https://kubernetes.io/docs/concepts/workloads/controllers/job/) documentation for creation and configuration details.

* Create a Job named **`random-hash`**. It should use the **`alpine:3.17.3`** container image and execute the shell command: **`echo $RANDOM | base64 | head -c 20`**.
* Configure this Job to run with **two parallel Pods** and ensure a total of **five successful completions**.
* **Identify the Pods** that successfully ran the shell command. Based on the configuration, **how many Pods do you anticipate will be created** in total?
* Retrieve the **generated hash** output from the container logs of one of the completed Pods.
* **Delete the Job**. Do the associated Pods persist after the deletion?

***

## Task 2: CronJobs

Refer to the [**CronJobs**](https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/) documentation for creation and configuration details.

* Create a new CronJob named **`google-ping`**. This Job should execute a **`curl`** command against **`google.com`** when it runs. Select a suitable container image for this task. The execution schedule must be **every two minutes**.
* **Monitor the creation** of the underlying Jobs that the CronJob manages. (Hint: Review the command-line options of the relevant monitoring command or consult the Kubernetes documentation.)
* Modify the CronJob to **retain a history** of **seven** successful/failed executions.
* **Reconfigure the CronJob** to prevent a new execution from starting if the previous one is still active (concurrent execution should be disallowed). (Hint: Consult the Kubernetes documentation for the relevant field.)
