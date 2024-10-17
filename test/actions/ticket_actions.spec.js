import { notifyOfMessage } from "../../app/assets/javascripts/actions/tickets_actions";
import {
  ADD_NOTIFICATION,
  API_FAIL,
} from "../../app/assets/javascripts/constants";
import request from "../../app/assets/javascripts/utils/request";

jest.mock("../../app/assets/javascripts/utils/request"); // Mock the request module

describe("notifyOfMessage", () => {
  const mockDispatch = jest.fn();

  beforeEach(() => {
    jest.clearAllMocks(); // Clears mocks before each test
  });

  it("should dispatch ADD_NOTIFICATION on successful request", async () => {
    const mockResponse = {
      ok: true,
      json: jest.fn().mockResolvedValue({}),
    };
    request.mockResolvedValue(mockResponse);

    const body = { message: "Test message" };
    await notifyOfMessage(body)(mockDispatch);

    expect(request).toHaveBeenCalledWith("/tickets/notify_owner", {
      body: JSON.stringify(body),
      method: "POST",
    });

    expect(mockDispatch).toHaveBeenCalledWith({
      type: ADD_NOTIFICATION,
      notification: {
        message: "Email was sent to the owner.",
        type: "success",
        closable: true,
      },
    });
  });

  it("should dispatch API_FAIL when response is not ok and has a message", async () => {
    const mockResponse = {
      ok: false,
      json: jest.fn().mockResolvedValue({ message: "Something went wrong" }),
    };
    request.mockResolvedValue(mockResponse);

    const body = { message: "Test message" };
    await notifyOfMessage(body)(mockDispatch);

    expect(request).toHaveBeenCalledWith("/tickets/notify_owner", {
      body: JSON.stringify(body),
      method: "POST",
    });

    expect(mockDispatch).toHaveBeenCalledWith({
      type: API_FAIL,
      data: { statusText: "Something went wrong" },
    });
  });

  it("should dispatch API_FAIL with default error message on request failure", async () => {
    request.mockRejectedValue(new Error("Network Error"));

    const body = { message: "Test message" };
    await notifyOfMessage(body)(mockDispatch);

    expect(request).toHaveBeenCalledWith("/tickets/notify_owner", {
      body: JSON.stringify(body),
      method: "POST",
    });

    expect(mockDispatch).toHaveBeenCalledWith({
      type: API_FAIL,
      data: { statusText: "Email could not be sent." },
    });
  });
});
