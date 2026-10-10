import NetworkApp from "../components/NetworkApp";
import PlatformDesignProvider from "../components/PlatformDesignProvider";
import {TrustWeaveRuntimeProfiler} from "../tools/trustweave_tool/TrustWeaveRuntime";

export default function Home() {
  return <PlatformDesignProvider><TrustWeaveRuntimeProfiler name="TrustWeave.NetworkApp"><NetworkApp /></TrustWeaveRuntimeProfiler></PlatformDesignProvider>;
}
