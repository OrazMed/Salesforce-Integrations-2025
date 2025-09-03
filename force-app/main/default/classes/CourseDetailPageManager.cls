/**
 * URL = instanceURL + '/services/apexrest/v1/CourseDetailPageManager/'
 * instanceUrl = classic version org url
 */
@RestResource(urlMapping = '/v1/CourseDetailPageManager/*')
global with sharing class CourseDetailPageManager {
    
    @httpGet
    global static CourseDetailsWrapper getCourseDetails() {
        CourseDetailsWrapper wrapper = new CourseDetailsWrapper();

        try {
            List<Course__c> courses = [SELECT Id, Name, Active__c, Level__c,
                                        (SELECT Id, Name, Active_Session__c, Session_Number__c FROM Scheduled_Sessions__r),
                                        (SELECT Id, Name, Instructor_Email__c FROM Instructors__r),
                                        (SELECT Id, Name, Country__c FROM Course_Locations__r),
                                        (SELECT Id, Name, Image_URL__c, Type__c FROM Course_Images__r)
                                        FROM Course__c];

            wrapper.status = 'SUCCESS';
            wrapper.numberOfCourses = courses.size();

            if(courses.size() > 0) {
                wrapper.message = 'Everything seems to be working fine.';
                wrapper.courses = new List<Courses>();
                for(Course__c course: courses) {
                    Courses courseWrapper = new Courses();
                    courseWrapper.id = course.Id;
                    courseWrapper.name = course.Name;
                    courseWrapper.active = course.Active__c;
                    courseWrapper.level = course.Level__c;
                    courseWrapper.scheduledSessions = course.Scheduled_Sessions__r;
                    courseWrapper.instructors = course.Instructors__r;
                    courseWrapper.courseLocations = course.Course_Locations__r;
                    courseWrapper.courseImages = course.Course_Images__r;

                    wrapper.courses.add(courseWrapper);
                }
                //wrapper.courses = courseWrapper;
            } else {
                wrapper.message = 'Oops! Looks like there are no courses available.';
            }
        } catch (QueryException e) {
            wrapper.status = 'ERROR';
            wrapper.message = 'Something went wrong! Give the following error message to System Developer: ' + e.getMessage();
        }

        return wrapper;
    }


    global class CourseDetailsWrapper {
        global String status;
        global String message;
        global Integer numberOfCourses;
        global Courses[] courses;
        //global List<Course__c> courses;
    }

    global class Courses {
        global String id;
        global String name;
        global Boolean active;
        global String level;
        global List<Scheduled_Session__c> scheduledSessions;
        global List<Instructor__c> instructors;
        global List<Course_Location__c> courseLocations;
        global List<Course_Image__c> courseImages;
    }
}