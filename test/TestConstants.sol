// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;
uint32 constant _MAX_NR_OF_TIERS = 100;

/** @dev I am not able to change and store a (boolean) value over multiple fuzz runs in a single test contract.
Since I keep track of the hits of each test branch of the fuzz test runs cumulatively, I count how often
each branch is hit. Since I cannot preserve values over multiple fuzz runs (they are reset to their initial value each
run), I export the counts to a log file. However, if I run the test twice, I want to save the count of the last run
and not have a cumulative count of all test runs. So I try to distinguish each test run (which contains multiple fuzz
runs). However, since all values re-initialise I cannot know, within a run, whether the counter is reset or not.

So to resolve this, I create one temp.txt file if it does not yet exist, and then get the last time it is modified to
create the subdirectory for the fuzz test as that timestamp to ensure it is of the last fuzz run. I delete that
temp.txt manually when I run the tests.

I also tried using vm.unixTime() but that throws a revert (without explanation). Furthermore, I assume it changes for each
fuzz run.

A weird thing; when I create the log file in the `setUp` function, the counters are not updated (only once yielding 0,0,0,1,1),
and if I create the log file in the testFuzz run, the counters are updated (yielding 605,354 etc). I think this is
weird because I thought the setUp() function is ran before each Fuzz run, and even more weird because at the end of
each fuzz run, the hit rate in the log files is updated, which should lead to an increased count even though the setup
function was called only once instead of before each fuzz run/test.*/
string constant _LOG_TIME_CREATOR = "temp.txt"; // File used to create the timestamp to log the fuzz tests.
