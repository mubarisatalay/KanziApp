package com.kanzi.api.auth;

import com.kanzi.api.config.AppProperties;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;

@Service
public class MailService {

    private final JavaMailSender mailSender;
    private final AppProperties props;

    public MailService(JavaMailSender mailSender, AppProperties props) {
        this.mailSender = mailSender;
        this.props = props;
    }

    public void sendVerificationEmail(String to, String token) {
        String link = props.baseUrl() + "/api/v1/auth/verify?token=" + token;
        SimpleMailMessage message = new SimpleMailMessage();
        message.setFrom(props.mail().from());
        message.setTo(to);
        message.setSubject("Verify your KanziApp account");
        message.setText("""
                Welcome to KanziApp!

                Please verify your email address by opening this link:
                %s

                If you didn't create this account, you can ignore this message.
                """.formatted(link));
        mailSender.send(message);
    }
}
