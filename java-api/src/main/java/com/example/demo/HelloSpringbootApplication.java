package com.example.demo;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;
import org.springframework.web.filter.CommonsRequestLoggingFilter;

@SpringBootApplication
public class HelloSpringbootApplication {

    public static void main(String[] args) {
        SpringApplication.run(HelloSpringbootApplication.class, args);
    }

    /**
     * Filtre qui log chaque requête HTTP en console (stdout).
     * -> Collecté par Fluent Bit -> envoyé vers Elasticsearch -> visible dans Kibana.
     */
    @Bean
    public CommonsRequestLoggingFilter requestLoggingFilter() {
        CommonsRequestLoggingFilter f = new CommonsRequestLoggingFilter();
        f.setIncludeClientInfo(true);     // IP/Session/User
        f.setIncludeQueryString(true);    // ?param=...
        f.setIncludePayload(true);        // corps de requête (limité)
        f.setMaxPayloadLength(1000);      // limite du corps loggué
        f.setIncludeHeaders(false);       // headers souvent verbeux/sensibles
        return f;
    }
}
