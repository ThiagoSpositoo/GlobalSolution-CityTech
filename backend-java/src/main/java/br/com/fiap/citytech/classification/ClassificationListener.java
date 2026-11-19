package br.com.fiap.citytech.classification;

import br.com.fiap.citytech.messaging.OccurrenceCreatedEvent;
import br.com.fiap.citytech.messaging.RabbitTopologyConfig;
import org.springframework.amqp.rabbit.annotation.RabbitListener;
import org.springframework.stereotype.Component;

@Component
public class ClassificationListener {

    private final tools.jackson.databind.ObjectMapper objectMapper;
    private final ClassificationService service;

    public ClassificationListener(
            tools.jackson.databind.ObjectMapper objectMapper,
            ClassificationService service) {
        this.objectMapper = objectMapper;
        this.service = service;
    }

    @RabbitListener(queues = RabbitTopologyConfig.QUEUE)
    public void consume(String payload) {
        service.process(objectMapper.readValue(payload, OccurrenceCreatedEvent.class));
    }
}
