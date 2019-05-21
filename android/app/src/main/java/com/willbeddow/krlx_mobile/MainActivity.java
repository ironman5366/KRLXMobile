package com.willbeddow.krlx_mobile;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.graphics.Bitmap;
import android.media.AudioManager;
import android.media.MediaPlayer;
import android.os.AsyncTask;
import android.os.Build;
import android.os.Bundle;
import android.util.Log;

import androidx.core.app.NotificationCompat;
import androidx.core.app.NotificationManagerCompat;

import com.google.android.exoplayer2.ExoPlayerFactory;
import com.google.android.exoplayer2.SimpleExoPlayer;
import com.willbeddow.krlx_mobile.MediaHandler;

import java.net.URL;
import java.util.concurrent.atomic.AtomicInteger;

import io.flutter.app.FlutterActivity;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugins.GeneratedPluginRegistrant;


public class MainActivity extends FlutterActivity {
  private static final String CHANNEL = "krlx_mobile.willbeddow.com/media";
  private final AtomicInteger c = new AtomicInteger(0);
  SimpleExoPlayer player;

    MediaHandler Session;

  int currentShowNotification;

  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    GeneratedPluginRegistrant.registerWith(this);
    // MethodChannel to handle media notifications
    new MethodChannel(getFlutterView(), CHANNEL).setMethodCallHandler(
            (call, result) -> {
              if (call.method.equals("showNotify")){
                  String showName = call.argument("showName");
                  String hosts = call.argument("hosts");
                  showNotify(showName, hosts);
              }
              else if (call.method.equals("removeShowNotification")){
                  this.removeCurrentNotification();
              }
              else if (call.method.equals("play")){
                  String contentUrl = call.argument("contentUrl");
                  streamMusic(contentUrl);
              }
              else if (call.method.equals("pause")){
                  pauseMusic();
              }
              else{
                result.notImplemented();
              }
            }
    );

  }

  private void streamMusic(String contentUrl){
      System.out.println("Got contentURL");
  }

  private void pauseMusic(){
      System.out.println("Pausing music");
  }
  private int getNotificationIcon() {
        boolean useWhiteIcon = (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.LOLLIPOP);
        return R.drawable.ic_stat_radio;
  }
  private void createNotificationChannel() {
        // Create the NotificationChannel, but only on API 26+ because
        // the NotificationChannel class is new and not in the support library
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            CharSequence name = getString(R.string.channel_name);
            String description = getString(R.string.channel_description);
            String channel_id = getString(R.string.channel_id);
            int importance = NotificationManager.IMPORTANCE_DEFAULT;
            NotificationChannel channel = new NotificationChannel(channel_id, name, importance);
            channel.setDescription(description);
            // Register the channel with the system; you can't change the importance
            // or other notification behaviors after this
            NotificationManager notificationManager = getSystemService(NotificationManager.class);
            notificationManager.createNotificationChannel(channel);
        }
    }

  public void removeCurrentNotification(){
    if (this.currentShowNotification != 0){
        NotificationManager mNotificationManager = (NotificationManager)
                getSystemService(NOTIFICATION_SERVICE);
        mNotificationManager.cancel(this.currentShowNotification);
    }
  }

  public void showNotify(String showName, String hosts){
      // Start a media session
      //MediaPlayer mediaPlayer = MediaPlayer.create( )
      // If currentShowNotfication exists, delete it
      this.removeCurrentNotification();
      createNotificationChannel();
      String channel_id = getString(R.string.channel_id);
      Notification showNotification = new NotificationCompat.Builder(this, channel_id)
              .setSmallIcon(getNotificationIcon())
              .setContentTitle(showName)
              .setContentText(hosts)
              .build();
      int notificationId = this.c.incrementAndGet();
      this.currentShowNotification = notificationId;
      NotificationManagerCompat notificationManager = NotificationManagerCompat.from(this);

      // notificationId is a unique int for each notification that you must define
      notificationManager.notify(notificationId, showNotification);

  }
}
