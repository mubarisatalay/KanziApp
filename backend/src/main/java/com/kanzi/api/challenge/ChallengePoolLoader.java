package com.kanzi.api.challenge;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;
import org.yaml.snakeyaml.Yaml;

import java.io.InputStream;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * Seeds {@code pool_challenges} from {@code challenge-pool.yml} on startup.
 * Only inserts entries that are not already in the DB (matched by challenge text).
 * Existing rows are never deleted — retired prompts should be soft-deleted via
 * {@code active = false} directly in the database.
 */
@Component
public class ChallengePoolLoader implements ApplicationRunner {

    private static final Logger log = LoggerFactory.getLogger(ChallengePoolLoader.class);

    private final PoolChallengeRepository repository;

    public ChallengePoolLoader(PoolChallengeRepository repository) {
        this.repository = repository;
    }

    @Override
    @Transactional
    @SuppressWarnings("unchecked")
    public void run(ApplicationArguments args) throws Exception {
        ClassPathResource resource = new ClassPathResource("challenge-pool.yml");
        if (!resource.exists()) {
            log.warn("challenge-pool.yml not found on classpath — skipping pool seed");
            return;
        }

        List<Map<String, Object>> entries;
        try (InputStream in = resource.getInputStream()) {
            Map<String, Object> root = new Yaml().load(in);
            entries = (List<Map<String, Object>>) root.get("challenges");
        }
        if (entries == null || entries.isEmpty()) {
            return;
        }

        Set<String> existing = repository.findByActiveTrue().stream()
                .map(PoolChallenge::getChallengeText)
                .collect(Collectors.toSet());

        int inserted = 0;
        for (Map<String, Object> entry : entries) {
            String text = ((String) entry.get("text")).trim();
            if (existing.contains(text)) {
                continue;
            }
            String typeStr = (String) entry.get("type");
            ChallengeType type = ChallengeType.fromDb(typeStr)
                    .orElseThrow(() -> new IllegalArgumentException("Unknown challenge type in pool YAML: " + typeStr));
            boolean blind = Boolean.TRUE.equals(entry.get("blind"));

            PoolChallenge pc = new PoolChallenge();
            pc.setChallengeText(text);
            pc.setChallengeType(type.db());
            pc.setBlind(blind);
            repository.save(pc);
            inserted++;
        }

        if (inserted > 0) {
            log.info("ChallengePoolLoader: inserted {} new challenge(s) from challenge-pool.yml", inserted);
        } else {
            log.debug("ChallengePoolLoader: all pool entries already present, nothing to insert");
        }
    }
}
