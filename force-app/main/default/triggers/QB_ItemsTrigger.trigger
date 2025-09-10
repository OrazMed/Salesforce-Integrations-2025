trigger QB_ItemsTrigger on Product2 (after update) {

    ProductsTriggerHandler.handleBeforeUpdates(Trigger.New, Trigger.OldMap);
}