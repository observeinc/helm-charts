Gimport java.text.SimpleDateFormat;
import java.util.Date;
import java.util.logging.*;

public class ExceptionGenerator {

    private static final Logger LOGGER = Logger.getLogger(ExceptionGenerator.class.getName());

    private static final String[][] MESSAGES_WITH_DETAILS = {
        {"Processing transaction ", "TX12345"},
        {"User login attempt for ", "user@example.com"},
        {"Health check OK for ", "service-auth"},
        {"Payment gateway response received for ", "order #98765"}
    };

    // 🧾 Custom Formatter to match: 2025-04-09 21:31:21.295:INFO::
    public static class CustomFormatter extends Formatter {
        private static final SimpleDateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss.SSS");

        @Override
        public String format(LogRecord record) {
            StringBuilder sb = new StringBuilder();
            sb.append(dateFormat.format(new Date(record.getMillis())))
              .append(":")
              .append(record.getLevel().getName())
              .append(":: ")
              .append(formatMessage(record))
              .append("\n");
            return sb.toString();
        }
    }

    // 🛠️ Helper to format full stack trace (including causes)
    private static String formatStackTrace(Throwable e) {
        StringBuilder sb = new StringBuilder();
        sb.append(e.toString()).append("\n");
        for (StackTraceElement element : e.getStackTrace()) {
            sb.append("    at ").append(element.toString()).append("\n");
        }
        Throwable cause = e.getCause();
        while (cause != null) {
            sb.append("Caused by: ").append(cause.toString()).append("\n");
            for (StackTraceElement element : cause.getStackTrace()) {
                sb.append("    at ").append(element.toString()).append("\n");
            }
            cause = cause.getCause();
        }
        return sb.toString();
    }

    // Throws ArithmeticException
    private static void generateSimpleError() {
        try {
            int result = 42 / 0;
        } catch (Exception e) {
            LOGGER.severe("Simple ArithmeticException occurred:\n" + formatStackTrace(e));
        }
    }

    // Throws complex nested exception
    private static void generateComplexNestedError() {
        try {
            simulateServiceLayer();
        } catch (Exception e) {
            LOGGER.severe("Complex nested exception occurred:\n" + formatStackTrace(e));
        }
    }

    private static void simulateServiceLayer() {
        try {
            simulateRepositoryLayer();
        } catch (Exception e) {
            throw new IllegalStateException("Service layer failed", e);
        }
    }

    private static void simulateRepositoryLayer() {
        try {
            simulateDatabaseCall();
        } catch (Exception e) {
            NullPointerException npe = new NullPointerException("Repository returned null object");
            npe.initCause(e);
            throw npe;
        }
    }

    private static void simulateDatabaseCall() {
        throw new RuntimeException("Database connection timeout");
    }

    public static void main(String[] args) {
        // ⬇️ Set up custom log format
        for (Handler handler : LOGGER.getParent().getHandlers()) {
            if (handler instanceof ConsoleHandler) {
                handler.setFormatter(new CustomFormatter());
            }
        }

        for (int i = 0; i < 100000; i++) {
            LOGGER.info("Heartbeat from instance #" + i);
            LOGGER.warning("Minor warning on iteration #" + i);

            for (String[] messageDetails : MESSAGES_WITH_DETAILS) {
                String message = messageDetails[0];
                String details = messageDetails[1];
                LOGGER.info(message + details);
            }

            // ⏱️ Wait before throwing an error
            try {
                Thread.sleep(2000); // 2s delay
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }

            // Alternate between exception types
            if (i % 2 == 0) {
                generateSimpleError();
            } else {
                generateComplexNestedError();
            }

            // ⏱️ Wait before next batch
            try {
                Thread.sleep(5000); // 5s delay
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
        }
    }
}
