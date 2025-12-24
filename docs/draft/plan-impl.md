Once the plan is approved by the user, the plan is created as a Github Issue for tracking.

The development then proceeds to implementation phase via the `/issue2impl` command.
We have a plan adjuster persona agent to adjust the plan implementation based on the difficulties.
First, a new branch is forked from `main` for the implementation.
0. The very first commit to this branch is to update the documentation related to this plan.
1. Then all the test cases related to this plan shall be created/updated to ensure the implementation is test-driven.
2. Then we have a `\towards-next-milestone` skill to implement the plan step by step.
   - If the development is approaching 800 lines wihtout completing the plan, the agent shall stop and create a milestone document to track the progress.
2. Continue on the `\towards-next-milestone` skill in the next session until the plan is fully implemented. (User intervention is REQUIRED here to start the next session.)
3. The symbol of delivering the full implementation is to pass all the test cases.
4. After passing all the test cases, before pull request, a code reviewer persona agent is used to review the code quality and suggest improvements.
5. Finally, a pull request is created for user to review and merge the code into `main`.