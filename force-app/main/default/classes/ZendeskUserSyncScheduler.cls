public class ZendeskUserSyncScheduler  implements Schedulable{
    
    public void execute(SchedulableContext sc) {
        ZendeskUserSynchBatch bj = new ZendeskUserSynchBatch();

        Database.executeBatch(bj, 100);
    }

    /*
        On Anonymous window:
            // Check if the job is already scheduled to avoid duplicates
            List<CronTrigger> existingJobs = [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name = 'Zendesk User Daily Sync'];
            if(existingJobs.isEmpty()) {
                String cronExpression = '0 0 15 8 8 ? 2025'; // sec min hour dayOfMonth month dayOfWeek : 15:00:00 8/Aug/2025
                String jobName = 'Zendesk User Daily Sync';
                ZendeskUserSyncScheduler scheduler = new ZendeskUserSyncScheduler();
                System.schedule(jobName, cronExpression, scheduler);

                System.debug('Successfully scheduled Zendesk User Daily Sync job.');
            }else {
                System.debug('Successfully scheduled Zendesk User Daily Sync job.');
            }
    */
}