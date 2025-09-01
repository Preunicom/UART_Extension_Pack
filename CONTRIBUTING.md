# Contributing to UART_Extension_Pack

Your are welcome to contribute to the project by creatign pull requests.  

## Setup
Make sure you have a supported FPGA ready to test your code on.

## Add unit

You are free in implementing the units itself.  
Try to orientate your code style on the existing code and stay modular.  
The wrapper entities have to be in the same format to ensure easy handling by the user.  
Additionally, a common structure of the wrapper provides easier understanding and troubleshooting in the wrapper, so stay with it and adapt it to your needs.

1) Add your **unit** functionality in the src/Units folder or in a subfolder of it
2) Add a **wrapper** for your unit in the project wide used naming format and with the same default ports and generics all other wrapper use (you can add more). Use the same structure and functionality (edited to your unit) all other wrappers provides.
2) **Implement** and **document** (Doxygen comments) the functionality of both (orientate on other unit implementations)
3) Write a **test bench** for each entity you created and stay in the same test bench structure as all other test benches.
4) **Document** your test bench shortly like the others are.
5) **Test** your code with the **test bench**.
6) **Test** your code on your **FPGA(s)**.
7) **Review your documentation** (Doxygen + README)

## Issues

GitHub issues are used to report bugs or request features in this project.  
Please use the issue templates to create a new issue and fill it out properly.

## License

By contributing to the project, you agree that your contributions will be licensed
under the LICENSE file in the root directory of this source tree.
   
