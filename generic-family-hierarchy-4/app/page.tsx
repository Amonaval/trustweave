import NetworkApp from "../components/NetworkApp";
import PlatformDesignProvider from "../components/PlatformDesignProvider";
import RuntimeProfiler from "../tools/runtime-observability/react/RuntimeProfiler";

export default function Home() {
  return <RuntimeProfiler name="NetworkApp"><PlatformDesignProvider><NetworkApp /></PlatformDesignProvider></RuntimeProfiler>;
}
