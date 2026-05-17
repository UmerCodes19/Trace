export default function TraceAPIHome() {
  return (
    <div className="min-h-screen bg-black text-white flex flex-col items-center justify-center font-mono p-4">
      <div className="border border-neutral-800 bg-neutral-950 p-8 rounded-lg max-w-md w-full text-center space-y-4 shadow-2xl">
        <div className="w-3 h-3 bg-green-500 rounded-full mx-auto animate-pulse"></div>
        <h1 className="text-xl font-bold uppercase tracking-widest text-neutral-200">
          Trace API Core
        </h1>
        <p className="text-xs text-neutral-500 uppercase tracking-widest">
          Status: Online & Routing
        </p>
        <div className="pt-4 mt-4 border-t border-neutral-800/50 flex flex-col gap-2">
          <a href="/admin" className="text-[10px] text-neutral-400 hover:text-white transition-colors uppercase tracking-[0.2em]">
            &rarr; Access Admin Dashboard
          </a>
          <a href="/setup" className="text-[10px] text-neutral-600 hover:text-neutral-400 transition-colors uppercase tracking-[0.2em] mt-2">
            &rarr; Initialize Admin Setup
          </a>
        </div>
      </div>
    </div>
  );
}
