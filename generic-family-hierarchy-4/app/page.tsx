import NetworkApp from "../components/NetworkApp";
import PlatformDesignProvider from "../components/PlatformDesignProvider";
import RuntimeProfiler from "../tools/react-runtime-toolkit/react/RuntimeProfiler";

export default function Home() {
  return <PlatformDesignProvider><RuntimeProfiler name="TrustWeave.NetworkApp"><NetworkApp /></RuntimeProfiler></PlatformDesignProvider>;
}
