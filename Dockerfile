FROM lubien/tired-proxy:2 as proxy

# In future we may want to specify the Dart SDK base image version using dart:<version> (ex: dart:2.19)
# for now we default to stable.
FROM dart:stable AS build

# Resolve app dependencies.
WORKDIR /app
COPY pubspec.* ./

RUN dart pub get

# Copy app source code.
COPY . .
# Ensure packages are still up-to-date if anything has changed
RUN dart pub get --offline
# Compile a kernel snapshot snapshot.
RUN dart compile kernel bin/server.dart -o bin/snapshot.kernel --verbosity=warning

# Build minimal serving image.
FROM scratch
# Add Dart SDK to path.
ENV DART_SDK /usr/lib/dart
ENV PATH $DART_SDK/bin:$PATH
# Copy required system libraries and configuration files stored in `/runtime/` for Dart.
COPY --from=build /runtime/ /
# Copy Dart binaries and snapshots required to run the Dart binary.
COPY --from=build /usr/lib/dart/bin/dart /usr/lib/dart/bin/dart
COPY --from=build /usr/lib/dart/bin/snapshots/dartdev.dill /usr/lib/dart/bin/snapshots/dartdev.dill

# Copy files required for entrypoint
COPY --from=build /bin/sh /bin/sh
COPY --from=proxy /tired-proxy /tired-proxy
COPY --from=build /app/entrypoint.sh /entrypoint.sh

# Copy the users compiled kernel snapshot.
COPY --from=build /app/bin/snapshot.kernel /app/bin/

# Start server.
EXPOSE 8080
ENTRYPOINT ["/entrypoint.sh"]
