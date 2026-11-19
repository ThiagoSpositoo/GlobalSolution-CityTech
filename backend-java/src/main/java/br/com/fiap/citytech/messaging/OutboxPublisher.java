package br.com.fiap.citytech.messaging;

import java.time.Instant;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

@Component
@ConditionalOnProperty(
        name = "citytech.messaging.publisher-enabled",
        havingValue = "true",
        matchIfMissing = true)
public class OutboxPublisher {

    private static final Logger LOGGER = LoggerFactory.getLogger(OutboxPublisher.class);

    private final OutboxEventRepository repository;
    private final RabbitTemplate rabbitTemplate;

    public OutboxPublisher(OutboxEventRepository repository, RabbitTemplate rabbitTemplate) {
        this.repository = repository;
        this.rabbitTemplate = rabbitTemplate;
    }

    @Scheduled(fixedDelayString = "${citytech.messaging.publisher-delay-ms:2000}")
    @Transactional
    public void publishPending() {
        for (var event : repository.findTop50ByPublishedAtIsNullOrderByOccurredAtAsc()) {
            try {
                rabbitTemplate.convertAndSend(
                        RabbitTopologyConfig.EXCHANGE,
                        RabbitTopologyConfig.ROUTING_KEY,
                        event.getPayload(),
                        message -> {
                            message.getMessageProperties().setContentType("application/json");
                            message.getMessageProperties().setMessageId(event.getId().toString());
                            message.getMessageProperties().setHeader("eventType", event.getEventType());
                            message.getMessageProperties().setHeader(
                                    "schemaVersion",
                                    event.getSchemaVersion());
                            return message;
                        });
                event.markPublished(Instant.now());
            } catch (RuntimeException exception) {
                event.markFailed(exception.getClass().getSimpleName());
                LOGGER.warn(
                        "Falha ao publicar evento do outbox. eventId={} attempts={}",
                        event.getId(),
                        event.getAttempts());
            }
        }
    }
}
