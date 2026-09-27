import {DEFAULT_CATALOG} from "../lib/i18n/catalog";
import type { Metadata, Viewport } from "next";
import "./globals.css";
import { LanguageProvider } from "../lib/i18n";
import { ThemeProvider } from "../components/ThemeProvider";
import {NxReviewProvider} from "../lib/nx-review";
import PwaRuntime from "../components/PwaRuntime";
import RuntimeObservabilityBridge from "../tools/runtime-observability/react/RuntimeObservabilityBridge";


export const viewport: Viewport = {
  width: "device-width",
  initialScale: 1,
  viewportFit: "cover",
};

export const metadata: Metadata = {
  title: DEFAULT_CATALOG.SetupBrandTxt,
  description: DEFAULT_CATALOG.APrivateLivingHomeForYourFamilyTxt,
  manifest: "/manifest.json"
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return <html lang="en" data-theme="light"><body><RuntimeObservabilityBridge><ThemeProvider><LanguageProvider><NxReviewProvider>{children}<PwaRuntime/></NxReviewProvider></LanguageProvider></ThemeProvider></RuntimeObservabilityBridge></body></html>;
}
