package main
import (
    "net"
    "os"
    "time"
)

func main() {

    if len(os.Args) < 4 {
      println("No arguments!")
      os.Exit(1)
    } 
    
    host := os.Args[1]
    port := os.Args[2]
    msg := os.Args[3]

    msg2send := string(msg) + "\n"
    servAddr := string(host) + ":" + string(port)
    tcpAddr, err := net.ResolveTCPAddr("tcp", servAddr)
    if err != nil {
        println("ResolveTCPAddr failed:", err.Error())
        os.Exit(1)
    }

    conn, err := net.DialTCP("tcp", nil, tcpAddr)
    if err != nil {
        println("Dial failed:", err.Error())
        os.Exit(1)
    }

    _, err = conn.Write([]byte(msg2send))
    if err != nil {
        println("Write to server failed:", err.Error())
        os.Exit(1)
    }

 
    reply := make([]byte, 1024)

    // 20 - timeout to read from connection
    conn.SetReadDeadline(time.Now().Add(20 * time.Second))

    _, err = conn.Read(reply)
    if err != nil {
        println("Write to server failed:", err.Error())
        os.Exit(1)
    }

    print(string(reply))

    conn.Close()
}
