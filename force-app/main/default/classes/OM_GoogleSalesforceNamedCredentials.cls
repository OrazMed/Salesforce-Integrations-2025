public with sharing class OM_GoogleSalesforceNamedCredentials {
    public static void createCalendarEventUsingNamedCreds() {
        String parameters = '?sendNotifications=true&sendUpdates=all&supportsAttachments=true&alt=json&prettyPrint=true';
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:Google/calendar/v3/calendars/useroraz@gmail.com/events' + parameters);
        req.setHeader('Content-Type','application/json');
        //req.setHeader('Accept','application/json');
        req.setMethod('POST');
        String reqBody = '{'+
                '  "end": {'+
                '    "date": "2025-09-30"'+
                '    '+
                '  },'+
                '  "start": {'+
                '    "date": "2025-09-26"'+
                '    '+
                '  },'+
                '  "attendees": ['+
                '    {'+
                '      "displayName": "Hey Mamacita",'+
                '      "email": "useroraz@gmail.com"'+
                '      '+
                '    }'+
                '    '+
                '  ],'+
                '  "attachments": ['+
                '    {'+
                '      "title": "TEST wed",'+
                '      "fileUrl": "https://www.canva.com/design/DAGV6qwm7rk/ZNoKvNnWRtSvqgp-D37UhA/edit"'+
                '      '+
                '    }'+
                '    '+
                '  ],'+
                '  "summary": "Testing Google Event API",'+
                '  "description": "Testing Google Event API with Named Credentials",'+
                '  "organizer": {'+
                '    "displayName": "PowerMan",'+
                '    "email": "useroraz@gmail.com"'+
                '    '+
                '  }'+
                '  '+
                '}';
        req.setBody(reqBody);

        HTTP HTTP = new HTTP();
        HTTPResponse res = http.send(req);

        System.debug('STATUS: ' + res.getStatusCode());
        System.debug('BODY: ' + res.getBody());
        System.debug('Pretty Body::: ' + System.JSON.serializePretty(res.getBody()));

    }
}