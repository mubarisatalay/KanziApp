package com.kanzi.api.storage;

import com.kanzi.api.common.ApiException;
import com.kanzi.api.config.AppProperties;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;

import java.io.IOException;
import java.util.UUID;

@Service
public class StorageService {

    private final S3Client s3;
    private final AppProperties props;

    public StorageService(S3Client s3, AppProperties props) {
        this.s3 = s3;
        this.props = props;
    }

    /** Uploads an image and returns its public URL. Same key scheme as the old Supabase bucket. */
    public String uploadChallengeImage(MultipartFile file, UUID roomId, UUID challengeId, UUID userId) {
        String extension = extensionOf(file.getOriginalFilename());
        String key = "%s/%s/%s_%d.%s".formatted(
                roomId, challengeId, userId, System.currentTimeMillis(), extension);

        AppProperties.Storage storage = props.storage();
        try {
            s3.putObject(PutObjectRequest.builder()
                            .bucket(storage.bucket())
                            .key(key)
                            .contentType(file.getContentType())
                            .build(),
                    RequestBody.fromInputStream(file.getInputStream(), file.getSize()));
        } catch (IOException e) {
            throw new ApiException(org.springframework.http.HttpStatus.INTERNAL_SERVER_ERROR,
                    "Failed to upload image: " + e.getMessage());
        }

        return storage.publicUrl() + "/" + storage.bucket() + "/" + key;
    }

    private static String extensionOf(String filename) {
        if (filename == null || !filename.contains(".")) {
            return "jpg";
        }
        String ext = filename.substring(filename.lastIndexOf('.') + 1).toLowerCase();
        return ext.isBlank() ? "jpg" : ext;
    }
}
