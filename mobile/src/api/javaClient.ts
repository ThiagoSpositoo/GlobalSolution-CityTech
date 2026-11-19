import { apiConfig } from './config';
import { createHttpClient } from './http';
export const javaClient = createHttpClient(apiConfig.javaBaseUrl);
