# Lightweight Linux base with OpenJDK 17 (required for recent sdkmanager)
FROM ubuntu:22.04 AS build

ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies including OpenJDK 17 and xz-utils (needed for tar -J)
RUN apt-get update
RUN apt-get install -y --no-install-recommends openjdk-17-jdk
RUN apt-get install -y --no-install-recommends git
RUN apt-get install -y --no-install-recommends curl
RUN apt-get install -y --no-install-recommends unzip
RUN apt-get install -y --no-install-recommends zip
RUN apt-get install -y --no-install-recommends ca-certificates
RUN apt-get install -y --no-install-recommends xz-utils
RUN rm -rf /var/lib/apt/lists/*

RUN curl -L https://ziglang.org/builds/zig-x86_64-linux-0.16.0-dev.1484+d0ba6642b.tar.xz | tar -Jx -C /opt \
    && ln -s /opt/zig-x86_64-linux-0.16.0-dev.1484+d0ba6642b/zig /usr/local/bin/zig

ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV PATH=${JAVA_HOME}/bin:${PATH}

WORKDIR /app

# Download Android Command Line Tools (Linux) - stable recent version
RUN curl -o cmdtools.zip https://dl.google.com/android/repository/commandlinetools-linux-13114758_latest.zip \
    && unzip cmdtools.zip \
    && mkdir -p /opt/android/cmdline-tools/latest \
    && mv cmdline-tools/* /opt/android/cmdline-tools/latest/ \
    && rm -rf cmdtools.zip cmdline-tools

ENV ANDROID_SDK_ROOT=/opt/android
ENV PATH=${PATH}:${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin:${ANDROID_SDK_ROOT}/platform-tools

# Accept licenses (ignore potential non-zero exit code) and install packages
RUN yes | sdkmanager --licenses || true

RUN sdkmanager "platform-tools" "build-tools;33.0.2" "ndk;25.2.9519653" "platforms;android-32"

# Fix for git clone over HTTPS in non-interactive Docker environment
RUN git config --global credential.helper store

# Clone the project
RUN git clone https://github.com/Parker-P/android-zig-base .

# Build steps (Linux paths/commands)
RUN ${ANDROID_SDK_ROOT}/build-tools/33.0.2/aapt2 compile -o compiled_res.zip --dir res

RUN ${ANDROID_SDK_ROOT}/build-tools/33.0.2/aapt2 link -o unsigned.apk \
    -I ${ANDROID_SDK_ROOT}/platforms/android-32/android.jar \
    --manifest AndroidManifest.xml \
    compiled_res.zip

RUN javac -d . -source 8 -target 8 \
    -bootclasspath ${ANDROID_SDK_ROOT}/platforms/android-32/android.jar \
    -classpath ${ANDROID_SDK_ROOT}/platforms/android-32/android.jar \
    -Xlint:-options \
    ./MainActivity.java

RUN cp -r com/example/minimalnative/* .

RUN java -cp "${ANDROID_SDK_ROOT}/build-tools/33.0.2/lib/d8.jar" com.android.tools.r8.D8 \
    --min-api 24 --output . *.class

RUN zip -X -0 unsigned.apk classes.dex

RUN zig build

RUN mkdir -p lib/arm64-v8a \
    && cp zig-out/lib/libmain.so lib/arm64-v8a/libmain.so

RUN zip -X -0 unsigned.apk lib/arm64-v8a/libmain.so

RUN ${ANDROID_SDK_ROOT}/build-tools/33.0.2/zipalign -f -p -v 4 unsigned.apk aligned.apk

RUN if [ ! -e /path/to/your/file ]; then \
    keytool -genkeypair -keystore my-upload-key.jks -alias my-app-key -keyalg RSA -keysize 4096 -validity 20000 -dname "CN=Paolo Parker, O=KissMyApp, C=US" -storepass pass123 -keypass pass123 -noprompt; \
fi 

RUN ${ANDROID_SDK_ROOT}/build-tools/33.0.2/apksigner sign --ks my-upload-key.jks --ks my-upload-key.jks --ks-key-alias my-app-key --ks-pass pass:pass123 --key-pass pass:pass123 --ks-key-alias my-app-key --v4-signing-enabled true --out final.apk aligned.apk

FROM scratch AS export
COPY --from=build /app/final.apk /final.apk