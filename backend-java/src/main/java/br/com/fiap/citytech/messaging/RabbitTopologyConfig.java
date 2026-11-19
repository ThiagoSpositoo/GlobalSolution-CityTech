package br.com.fiap.citytech.messaging;

import org.springframework.amqp.core.Binding;
import org.springframework.amqp.core.BindingBuilder;
import org.springframework.amqp.core.Queue;
import org.springframework.amqp.core.QueueBuilder;
import org.springframework.amqp.core.TopicExchange;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class RabbitTopologyConfig {

    public static final String EXCHANGE = "citytech.occurrences";
    public static final String ROUTING_KEY = "occurrence.created.v1";
    public static final String QUEUE = "citytech.ai.classification.v1";
    public static final String DEAD_LETTER_EXCHANGE = "citytech.occurrences.dlx";
    public static final String DEAD_LETTER_QUEUE = "citytech.ai.classification.dlq";

    @Bean
    TopicExchange occurrenceExchange() {
        return new TopicExchange(EXCHANGE, true, false);
    }

    @Bean
    TopicExchange deadLetterExchange() {
        return new TopicExchange(DEAD_LETTER_EXCHANGE, true, false);
    }

    @Bean
    Queue classificationQueue() {
        return QueueBuilder.durable(QUEUE)
                .deadLetterExchange(DEAD_LETTER_EXCHANGE)
                .deadLetterRoutingKey(ROUTING_KEY)
                .build();
    }

    @Bean
    Queue deadLetterQueue() {
        return QueueBuilder.durable(DEAD_LETTER_QUEUE).build();
    }

    @Bean
    Binding classificationBinding(Queue classificationQueue, TopicExchange occurrenceExchange) {
        return BindingBuilder.bind(classificationQueue)
                .to(occurrenceExchange)
                .with(ROUTING_KEY);
    }

    @Bean
    Binding deadLetterBinding(Queue deadLetterQueue, TopicExchange deadLetterExchange) {
        return BindingBuilder.bind(deadLetterQueue)
                .to(deadLetterExchange)
                .with(ROUTING_KEY);
    }
}
