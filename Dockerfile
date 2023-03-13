# In future we may want to specify the Dart SDK base image version using dart:<version> (ex: dart:2.19)
# for now we default to stable.
FROM dart:stable AS build

# Resolve app dependencies.
WORKDIR /app
COPY pubspec.* ./
RUN dart pub get

# Copy app source code and kernel compile it.
COPY . .
# Ensure packages are still up-to-date if anything has changed
RUN dart pub get --offline
# Compile a kernel snapshot snapshot.
RUN dart compile kernel bin/server.dart -o bin/snapshot.kernel --verbosity=warning

# Build minimal serving image from a kernel snapshot in `./bin` and required system
# libraries and configuration files stored in `/runtime/` from the build stage.
FROM scratch
ENV DART_SDK /usr/lib/dart
ENV PATH $DART_SDK/bin:$PATH
COPY --from=build /runtime/ /
# Copy Dart binaries and snapshots required to run the Dart binary.
COPY --from=build /usr/lib/dart/bin/dart /usr/lib/dart/bin/dart
COPY --from=build /usr/lib/dart/bin/dartaotruntime /usr/lib/dart/bin/dartaotruntime
COPY --from=build /usr/lib/dart/bin/snapshots/dartdev.dart.snapshot /usr/lib/dart/bin/snapshots/dartdev.dart.snapshot
# Copy the users compiled kernel snapshot.
COPY --from=build /app/bin/snapshot.kernel /app/bin/

# Start server.
EXPOSE 8080
CMD ["dart", "run", "/app/bin/snapshot.kernel"]
