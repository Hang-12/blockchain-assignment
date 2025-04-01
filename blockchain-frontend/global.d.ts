import { EthereumProvider } from '@metamask/detect-provider';

declare global {
  interface Window {
    ethereum?: EthereumProvider;
  }
}
