import { apiConfig } from './config';
import { createHttpClient } from './http';
export const dotnetClient = createHttpClient(apiConfig.dotnetBaseUrl);
