FROM ghcr.io/cirruslabs/flutter:stable
WORKDIR /app
COPY . .
RUN flutter pub get
RUN flutter build web --release
CMD ["cp", "-r", "build/web", "/output"]
