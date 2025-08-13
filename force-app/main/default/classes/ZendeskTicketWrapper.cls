public with sharing class ZendeskTicketWrapper {

    public class CreateTicket {
        public ticket ticket;
        public CreateTicket(String subject, String description, String priority, String requester_email, String name, String assignee_id) {
            this.ticket = new ticket();
            this.ticket.subject = subject;
            this.ticket.priority = priority;
            this.ticket.assignee_id = assignee_id != null ? Long.valueOf(assignee_id) : null;
            this.ticket.comment = new Comment(description);
            this.ticket.Requester = new Requester(name, requester_email);
        }
    }

    public class UpdateTicket {
        public ticket ticket;
        public UpdateTicket(String assigneeId) {
            this.ticket = new ticket();
            this.ticket.assignee_id = Long.valueOf(assigneeId);
        }
    }

    public class ticket {
        public String id;
        public String subject;
        public String priority;
        public Long assignee_id;
        public Comment comment;
        public Requester Requester;
    }

    public class Comment {
        public String body;
        public Comment(String body) { this.body = body; }
    }

    public class Requester {
        public String name;
        public String email;
        public Requester(String name, String email) {
            this.name = name;
            this.email = email;
        }
    }
}