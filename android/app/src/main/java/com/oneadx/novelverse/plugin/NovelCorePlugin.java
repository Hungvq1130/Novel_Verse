//// NovelCorePlugin.java
//public class NovelCorePlugin implements FlutterPlugin, MethodChannel.MethodCallHandler {
//    private MethodChannel channel;
//    private Context context;
//    private NovelRepository repo;
//    private final ExecutorService executors = Executors.newSingleThreadExecutor();
//    private final Handler main = new Handler(Looper.getMainLooper());
//
//    @Override public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
//        context = binding.getApplicationContext();
//        channel = new MethodChannel(binding.getBinaryMessenger(), "novel_core");
//        channel.setMethodCallHandler(this);
//        repo = new NovelRepository(context);
//    }
//
//    @Override public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
//        channel.setMethodCallHandler(null);
//        executors.shutdown();
//    }
//
//    @Override public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
//        switch (call.method) {
//            case "importTxt": {
//                String uriStr = call.argument("uri"); // content:// hoặc file://
//                executors.execute(() -> {
//                    try {
//                        long novelId = repo.importTxt(Uri.parse(uriStr));
//                        main.post(() -> result.success(novelId));
//                    } catch (Exception e) {
//                        main.post(() -> result.error("IMPORT_TXT_FAIL", e.getMessage(), null));
//                    }
//                });
//                break;
//            }
//            case "importEpub": {
//                String uriStr = call.argument("uri");
//                executors.execute(() -> {
//                    try {
//                        long novelId = repo.importEpub(Uri.parse(uriStr));
//                        main.post(() -> result.success(novelId));
//                    } catch (Exception e) {
//                        main.post(() -> result.error("IMPORT_EPUB_FAIL", e.getMessage(), null));
//                    }
//                });
//                break;
//            }
//            case "getNovels": {
//                int page = call.argument("page");
//                int pageSize = call.argument("pageSize");
//                executors.execute(() -> {
//                    List<Map<String, Object>> out = repo.getNovels(page, pageSize);
//                    main.post(() -> result.success(out));
//                });
//                break;
//            }
//            case "getChapters": {
//                long novelId = ((Number) call.argument("novelId")).longValue();
//                executors.execute(() -> {
//                    List<Map<String, Object>> out = repo.getChapters(novelId);
//                    main.post(() -> result.success(out));
//                });
//                break;
//            }
//            case "getChapterContent": {
//                long chapterId = ((Number) call.argument("chapterId")).longValue();
//                executors.execute(() -> {
//                    String content = repo.getChapterContent(chapterId);
//                    main.post(() -> result.success(content));
//                });
//                break;
//            }
//            case "updateProgress": {
//                long novelId = ((Number) call.argument("novelId")).longValue();
//                long chapterId = ((Number) call.argument("chapterId")).longValue();
//                int offset = call.argument("offset");
//                executors.execute(() -> {
//                    repo.updateProgress(novelId, chapterId, offset);
//                    main.post(result::success);
//                });
//                break;
//            }
//            case "search": {
//                String q = call.argument("q");
//                executors.execute(() -> {
//                    List<Map<String, Object>> out = repo.search(q);
//                    main.post(() -> result.success(out));
//                });
//                break;
//            }
//            default:
//                result.notImplemented();
//        }
//    }
//}
